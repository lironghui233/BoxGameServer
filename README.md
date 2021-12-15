
### 目录介绍

 - **etc**：存放服务配置的文件夹
 - **example**：测试用例
 - **luaclib**：存放一些C模块（.so文件）
 - **luaclib_src**：存放C模块的源代码（.c、.h）
 - **lualib**：存放Lua模块
 - **service**：存放各服务的Lua代码
 - **skynet**：skynet框架，我们不会改动skynet的任何内容。如果后续skynet有更新，直接替换该文件夹即可
 - **proto**：存放通信协议文件（.proto）
 - **storage**：存放数据库协议文件（.proto）
 - **tools**：存放工具文件
 - **start.sh**：启动服务的脚本（本质就是./skynet [配置]）

### 编译skynet

1. mkdir skynet
2. git clone https://github.com/cloudwu/skynet.git
3. cd skynet	
4. make linux

### 编译第三方脚本

lua-cjson下载与编译：
```
cd luaclib_src	#进入luaclib_src目录
git clone https://github.com/mpx/lua-cjson	#下载第三方库lua-cjson的源码
cd lua-cjson	#进入lua-cjson源码目录
make	#编译，成功后会多出名为cjson.so的文件
cp cjson.so ../../luaclib	#将cjson.so复制到存放C模块的luaclib目录中
```

pbc下载与编译：
```
cd luaclib_src	#进入项目工程luaclib_src目录
git clone https://github.com/cloudwu/pbc	#下载第三方库pbc的源码
cd pbc	#进入pbc源码目录
make	#编译pbc
cd pbc/binding/lua53	#进入pbc的binding目录，它包含skynet'可用的C库源码
make	#工具编译。成功后会在同目录下生成 库文件protobuf.so 和 Lua模块protobuf.lua
cp protobuf.so ../../../../luaclib/	#将protobuf.so复制到存放C模块的luaclib目录中
cp protobuf.lua ../../../../lualib/	#将protobuf.lua复制到存放Lua模块的lualib目录中
```

注意：编译pbc、pbc工具和cjson时，用的Lua版本和Skynet/3rd目录下的Lua版本要一致。目前新版的skynet支持了lua5.4.2，因此保证`lua -v`版本要和skynet支持的lua版本一致。否则会导致protobuf.so和cjson.so使用时会报错


### 运行

```
sh start.sh 1
```