#!/opt/local/bin/perl

package Apache2::AMFLiteDetectionFilter; 
  
  use strict; 
  use warnings;
  use MIME::Base64 qw(encode_base64);
  use Apache2::AMFCommonLib ();  
  use Apache2::RequestRec ();
  use Apache2::RequestUtil ();
  use Apache2::SubRequest ();
  use Apache2::Log;
  use Apache2::Filter (); 
  use APR::Table (); 
  use LWP::Simple;
  use Apache2::Const -compile => qw(OK REDIRECT DECLINED);
  use IO::Uncompress::Unzip qw(unzip $UnzipError) ;
  use constant BUFF_LEN => 1024;
  use Cache::FileBackend;


  #
  # Define the global environment
  # 

  use vars qw($VERSION);
  $VERSION= "4.04";
  my $CommonLib = new Apache2::AMFCommonLib ();
  my %MobileArray;#=$CommonLib->getMobileArray;
  my %MobileTabletArray;
  my %MobileTouchArray;
  my $cookiecachesystem="false";
  my $restmode='false';
  my $downloadparamurl='true';
  my $configMobileFile;
  my $forcetablet='true';
  my $configTabletFile;
  my $configTouchFile;
  my $checkVersion='true';
  my $mobilenable="false";
  
  my $urlmobile="http://www.apachemobilefilter.org/param/litemobiledetection.config";
  my $urlTablet="http://www.apachemobilefilter.org/param/litetabletdetection.config";
  my $urlTouch="http://www.apachemobilefilter.org/param/litetouchdetection.config";
  my $urlBot="http://www.apachemobilefilter.org/param/litebotdetection.config";
  my $bo;
  $CommonLib->printLog("---------------------------------------------------------------------------"); 
  $CommonLib->printLog("-------                 APACHE MOBILE FILTER V$VERSION                  -------");
  $CommonLib->printLog("------- support http://groups.google.com/group/amf-device-detection -------");
  $CommonLib->printLog("---------------------------------------------------------------------------");
  $CommonLib->printLog("----------------- AMF Lite Detection (not DR required)  -------------------");
  $CommonLib->printLog("---------------------------------------------------------------------------");
  $CommonLib->printLog("AMFLiteDetectionFilter module Version $VERSION");
  if ($ENV{AMFCheckVersion}) {
	$checkVersion=$ENV{AMFCheckVersion};
  }
  if ($checkVersion eq 'true') {
	$CommonLib->printLog("Check on apchemobilefilter.org if the installed AMF is the last version");  
        $CommonLib->printLog("Try to download http://www.apachemobilefilter.org/param/amf.config");
	my $url="http://www.apachemobilefilter.org/param/amf.config";
	my $content = get ($url);
	$content =~ s/\n//g;
	my $check_version=0;
	if ($content) {
	  $check_version=$content;
	}
        if ($check_version > $VERSION && $check_version ne 0) {
	       $CommonLib->printLog("---------------------------------------------------------------------------");
	       $CommonLib->printLog("-----           There is a new version of AMF V$check_version online             ----");
	       $CommonLib->printLog("---------------------------------------------------------------------------");
	} else {
		$CommonLib->printLog("AMF installed is the last version");
	}
  } else {
	$CommonLib->printLog("AMFCheckVersion is false, AMF don't check the last version.");
  }
  if ($ENV{AMFMobileHome}) {
	  $configMobileFile="$ENV{AMFMobileHome}/amflitedetection.config";
	  $configTabletFile="$ENV{AMFMobileHome}/amflitedetection_tablet.config";
	  $configTouchFile="$ENV{AMFMobileHome}/amflitedetection_touch.config";
   }  else {
	  $CommonLib->printLog("AMFMobileHome not exist. Please set the variable AMFMobileHome into httpd.conf");
   }
   if ($ENV{AMFProductionMode}) {
	$cookiecachesystem=$ENV{AMFProductionMode};
	$CommonLib->printLog("AMFProductionMode is: $cookiecachesystem");
   } else {
	$CommonLib->printLog("AMFProductionMode is not setted the default value is $cookiecachesystem");			   
   }
   if ($ENV{AMFMobileKeys}) {
	my @dummyMobileKeys = split(/,/, $ENV{AMFMobileKeys});
	foreach my $dummy (@dummyMobileKeys) {
		$MobileArray{$dummy}='mobile';
	}
	$CommonLib->printLog("AMFMobileKeys is: $ENV{AMFMobileKeys}");
    }
    if ($ENV{RestMode}) {
			$restmode=$ENV{RestMode};
			$CommonLib->printLog("RestMode is: $restmode");
    }
    if ($ENV{AMFDownloadParamURL}) {
	                        $downloadparamurl=$ENV{AMFDownloadParamURL};
				$CommonLib->printLog("DownloadAMFParamURL is: $downloadparamurl");
    }
    if ($downloadparamurl eq 'true') {
        &readMobileParamFromUrl;	
        &readTabletParamFromUrl;
        &readTouchParamFromUrl;
    } else {
	&readMobileParamFromFile;		
        &readTabletParamFromFile;
        &readTouchParamFromFile;
    }
    if ($ENV{ForceTabletAsFullBrowser}) {
		if ($ENV{ForceTabletAsFullBrowser} eq 'true') {
			$CommonLib->printLog("AMFMobileHome not exist. Please set the variable AMFMobileHome into httpd.conf");
			$forcetablet="true";
		} else {
			$forcetablet="false";
		}
     }
     if ($ENV{FullBrowserMobileAccessKey}) {
                          $mobilenable="$ENV{FullBrowserMobileAccessKey}";
                          $CommonLib->printLog("FullBrowserMobileAccessKey is: $ENV{FullBrowserMobileAccessKey}");
                          $CommonLib->printLog("For access the device to fullbrowser set the link: <url>?$mobilenable=true");
     }
sub readMobileParamFromUrl {
		$CommonLib->printLog("Read data from apachemobilefilter.org");
		my $content = get ($urlmobile);
		if ($content) {
			$CommonLib->printLog("Download OK");
			$content =~ s/\n//g;
			my @dummyMobileKeys = split(/,/, lc($content));
			foreach my $dummy (@dummyMobileKeys) {
				$MobileArray{$dummy}='mobile';
			}
			 open (MYFILE, ">$configMobileFile") || die ("Cannot Open File: $configMobileFile");
			    print MYFILE $content;
			 close (MYFILE);
		 } else {
			$CommonLib->printLog("Download error from apachemobilefilter.org");
			$CommonLib->printLog("Try download previews version");
			&readMobileParamFromFile;	
		}
}
sub readMobileParamFromFile {
		$CommonLib->printLog("Read for mobile data from $configMobileFile");
		my $content="";
		if (open (IN,$configMobileFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configMobileFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileArray{$dummy}='mobile';
		}
}
sub readTabletParamFromUrl {
		$CommonLib->printLog("Read data for tablet detection from apachemobilefilter.org");
		my $content = get ($urlTablet);
		if ($content) {
			$CommonLib->printLog("Download OK");
			$content =~ s/\n//g;
			my @dummyMobileKeys = split(/,/, lc($content));
			foreach my $dummy (@dummyMobileKeys) {
				$MobileTabletArray{$dummy}='mobile';
			}
			 open (MYFILE, ">$configTabletFile") || die ("Cannot Open File: $configMobileFile");
			    print MYFILE $content;
			 close (MYFILE);
		 } else {
			$CommonLib->printLog("Download error from apachemobilefilter.org");
			$CommonLib->printLog("Try download previews version");
			&readTabletParamFromFile;	
		}
}
sub readTabletParamFromFile {
		$CommonLib->printLog("Read data from $configTabletFile");
		my $content="";
		if (open (IN,$configTabletFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configTabletFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileTabletArray{$dummy}='mobile';
		}
}
sub readTouchParamFromUrl {
		$CommonLib->printLog("Read data for touch detection from apachemobilefilter.org");
		my $content = get ($urlTouch);
		if ($content) {
			$CommonLib->printLog("Download OK");
			$content =~ s/\n//g;
			my @dummyMobileKeys = split(/,/, lc($content));
			foreach my $dummy (@dummyMobileKeys) {
				$MobileTouchArray{$dummy}='mobile';
			}
			 open (MYFILE, ">$configTouchFile") || die ("Cannot Open File: $configMobileFile");
			    print MYFILE $content;
			 close (MYFILE);
		 } else {
			$CommonLib->printLog("Download error from apachemobilefilter.org");
			$CommonLib->printLog("Try download previews version");
			&readTouchParamFromFile;	
		}
}
sub readTouchParamFromFile {
		$CommonLib->printLog("Read data from $configTouchFile");
		my $content="";
		if (open (IN,$configTouchFile)) {
			while (<IN>) {
				$content=$content.$_;				 
			}
			close IN;
		} else {
			$CommonLib->printLog("Error open file:$configTouchFile");
			ModPerl::Util::exit();
		}
                $content =~ s/\n//g;
		my @dummyMobileKeys = split(/,/, lc($content));
		foreach my $dummy (@dummyMobileKeys) {
			$MobileTouchArray{$dummy}='mobile';
		}
}

sub isMobile {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isMobileValue='false';
  my $pair;
  my $length=0;
  foreach $pair (sort keys %MobileArray) {
     #  print "isMobile:$pair\n";
	if ($UserAgent =~ m/$pair/) {
    #            print "yes\n";
		$isMobileValue='true';
		$bo=$pair;
	}
  }
  return $isMobileValue;
}
sub isTablet {
  my ($UserAgent) = @_;
  my $ind=0;
  my $isTabletValue='false';
  my $pair;
  my $length=0;
  #print "tableStart";
  foreach $pair (sort keys %MobileTabletArray) {
      # print "isTablet:$pair\n";
	if ($UserAgent =~ m/$pair/) {
   #             print "yes\n";
		$isTabletValue='true';
	}
  }
  print "tableEnd";
  return $isTabletValue;
}
sub isTouch {
  my ($UserAgent) = @_;
  print "eccomi";
  my $ind=0;
  my $isTouchValue='false';
  my $length=0;
  foreach my $pair (sort keys %MobileTouchArray) {
      print "isTouch:$pair\n";
	if ($UserAgent =~ m/$pair/) {
                print "yes\n";
		$isTouchValue='true';
	}
  }
  return $isTouchValue;
}
my $amf_device_ismobile="";
my $user_agent=lc(" Mozilla/5.0 (Mobile; rv:18.1) Gecko/18.1 Firefox/18.1");
my $amf_device_istouch="false";
my $amf_device_istablet="false";
	if ($amf_device_ismobile eq "") {
		$amf_device_ismobile = &isMobile($user_agent);
                  print "Start";
		if ($amf_device_ismobile eq 'true') {
                  print "Start";
			$amf_device_istouch = &isTouch($user_agent);
			$amf_device_istablet=&isTablet($user_agent);
		} else {
                  print "NoStart";                  
                }
	}
print "amf_device_ismobile=$amf_device_ismobile\n";
print "amf_device_istouch=$amf_device_istouch\n";
print "amf_device_istable=$amf_device_istablet\n";
exit;
