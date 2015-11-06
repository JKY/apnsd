apnsd
=====
ERLANG 推送服务端

### Installing
=====
1. 下载安装 OTP (http://www.erlang.org).
	
		$ ./configure --prefix=/usr/local/erlang --with-ssl --enable-threads --enable-smp-support --enable-kernel-poll --enable-hipe --without-javac
		$ 	make && make install

   设置环境变量

		$ 	vi /etc/profile
		$ 	export PATH=$PATH:/usr/local/erlang/bin


2. git clone https://github.com/JKY/apnsd.git apnsd


3. download and compile libs 

		$ git clone git://github.com/TonyGen/bson-erlang.git bson
		$ git clone git://github.com/TonyGen/mongodb-erlang.git mongodb
		$ cd bson
		$ erlc -o ../apnsd/ebin -I include src/*.erl
		$ cd ../mongodb
		$ erlc -o ../apnsd/ -I include -I .. src/*.erl
		$ cd ..


4. compile apnsd
	
		$  cd apnsd
		$  erlc -o ebin -I include src/*.erl



### PHP API

for handling clients's restful requests, use apache & php, peb is a php module which as a cnode of erlang: 

1. install mypeb (http://code.google.com/p/mypeb/)
		
		$ phpize
		$ ./configure --with-erlanglib=/usr/local/erlang/lib/erlang/lib/erl_interface-3.8/lib/ --with-erlanginc=/usr/local/erlang/	  lib/erlang/lib/erl_interface-3.8/include/
		$ sudo make && make install 

2. add moudle peb.so to php.ini, if phpinfo() shown the peb has been loaded, it's ready, otherwise back to install peb.

notes: for mac os, link the development header files, otherwise the php will can't found the includes and libs (disable rootless first):
  
	  $ sudo ln -s /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/usr/include /usr/include
