apnsd
=====
ERLANG 推送服务端

### Installing
=====
1. - 下载安装 OTP (http://www.erlang.org).

	$ 	./configure --prefix=/usr/local/erlang --with-ssl --enable-threads --enable-smp-support --enable-kernel-poll --enable-hipe --without-javac

	$ 	make && make install

   - 设置环境变量

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