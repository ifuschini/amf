#!/opt/local/bin/perl
$user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13E188a Safari/601.1";
$user_agent=&cleanUA(lc($user_agent));
$amf_device_os=&getOperativeSystem($user_agent);
$amf_device_os_version=&getOperativeSystemVersion($user_agent,$amf_device_os);
print "-->".$amf_device_os."\n";
print "-->".$amf_device_os_version."\n";
exit;
sub cleanUA {
  my ($UserAgent) = @_;
  $UserAgent =~ s/google favicon//g;
  return $UserAgent;
}
sub getOperativeSystem {
  my ($UserAgent) = @_;
  my $returnValue="nc";
  my @osTypesArray = split(/,/, "android,iphone|ipad|ipod,windows phone,symbianos,blackberry,kindle");
  my $osNumber=0;
    foreach my $os (@osTypesArray){
        print $osNumber."->".$os."----".$user_agent."\n";
        if ($UserAgent =~ /$os/) {
            if ($osNumber ==  0 ) {
                $returnValue="android";
            } elsif ($osNumber ==  1 ) {
                $returnValue="ios";
            } elsif ($osNumber ==  2 ) {
                $returnValue="windows phone";
            } elsif ($osNumber ==  3 ) {
                $returnValue="symbian";
            } elsif ($osNumber ==  4 ) {
                $returnValue="kindle";
            } 
            return $returnValue;        
        }
        $osNumber++;        
    }
    return $returnValue;
}
sub getOperativeSystemVersion {
  my ($UserAgent, $os) = (@_);
  my $matchOS=0;
  my $regex_param='';
  my $return_value="nc";
    if ($os eq 'android') {
        $regex_param="android ([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'ios') {
        $regex_param=" os ([0-9]\\_[0-9](\\_[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'windows phone') {
        $regex_param="( phone| phone os) ([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } elsif ($os eq 'symbian') {
        $regex_param="symbianos/([0-9]\\.[0-9](\\.[0-9])?)";
        $matchOS=1;
    } 
    if ($matchOS == 1) {
        ($return_value) = ($UserAgent =~ /$regex_param/);
    }
    
  return $return_value;
    
}