#!/usr/bin/perl
use IO::Socket::INET;
$s=IO::Socket::INET->new(LocalHost=>"127.0.0.1",LocalPort=>1080,Proto=>"tcp",Listen=>5,Reuse=>1)or die"$!";
print"SOCKS5 on 1080\n";
while($c=$s->accept()){
if(fork()==0){
$c->sysread($b,2);
($v,$n)=unpack("CC",$b);
$c->sysread($b,$n);
$c->syswrite(pack("CC",5,0));
$c->sysread($b,4);
($v,$cmd,$r,$a)=unpack("CCCC",$b);
$c->sysread($b,1);
$l=unpack("C",$b);
$c->sysread($b,$l);
$addr=$b;
$c->sysread($b,2);
$port=unpack("n",$b);
$r=IO::Socket::INET->new(PeerHost=>$addr,PeerPort=>$port,Proto=>"tcp")or next;
$c->syswrite(pack("CCCC",5,0,0,1).pack("NN",0,0));
while($c->sysread($d,4096)){
$r->syswrite($d);
}
while($r->sysread($d,4096)){
$c->syswrite($d);
}
exit;
}
$c->close();
}




