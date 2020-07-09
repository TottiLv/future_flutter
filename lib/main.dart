import 'dart:async';
import 'dart:io';

import 'dart:isolate';

import 'package:flutter/foundation.dart';

String _data = "0";

void main() {
//  getData();
/*事件队列、微队列*/
//  testFuture();
//  testFutureOrder();
//  testFutureGroup();
//  testFutureAsync();
//  testFutureMicro();

/*Isolate*/
//  testIsolate();
//  testIsolatePort();
//  testIsolatePortAsync();

/*Compute*/
  computeTest();
  print("做其他事情");
}



void getData() async{
  print('开始=$_data');
  //后面的操作必须是异步才能await
  //当前函数必须是异步函数
  Future future = Future((){
    for (int i=0;i<1000000000;i++){
      _data = "网络数据";
    }
    throw Exception('网络异常');
    return "异步执行完成后返回";
  });
  /*
  //处理错误
  future.catchError((e){
    print('捕获到了：'+e.toString());
  }).then((value) {
    print('then 来了！${value}');
  });
  */

/*
  future.then((value) {
    print('then 来了！${value}');
  },onError: (e){
    print("异常来啦${e}");
  }).whenComplete(() {
    print("无论是异常还是正常执行都会完成");
  });
  */
  ////先then，后catch，当有exception捕获then就不会执行
  future.then((value) {
    print('then 来了！${value}');
  }).catchError((e){
    print('捕获到了：'+e.toString());
  }).whenComplete(() {
    print("结束啦");
  });
  /*
  //如果先catch，后then，那么即使有exception捕获也会继续执行then
  future.catchError((e){
    print('捕获到了：'+e.toString());
  }).then((value) {
    print('then 来了！${value}');
  }).whenComplete(() {
    print("结束啦");
  });
  */

  /*
  //注意then最好与catchError一起使用
  //then是上面异步方法执行完成后(用来接收参数)，才会执行的；不影响其他执行
  future.then((value) {
    print('then 来了！${value}');
  });
  */


  print("再干点其他事情");
}

void testFuture() {
  //多个任务按照添加顺序执行(单线程)
  Future((){
    return "任务1";
  }).then((value) => print("${value}结束"));
  Future((){
    return "任务2";
  }).then((value) => print("${value}结束"));
  Future((){
    return "任务3";
  }).then((value) => print("${value}结束"));
  Future((){
    return "任务4";
  }).then((value) => print("${value}结束"));
  Future((){
    return "任务5";
  }).then((value) => print("${value}结束"));
  print("任务添加完成");
}

void testFutureOrder() {
  //then比默认的Future默认的队列优先级高
  Future((){
    return "任务1";
  }).then((value) {
    print("${value}结束");
    return "任务4";
  }).then((value) {
    print("${value}结束");
  });
  Future((){
    return "任务2";
  }).then((value) => print("${value}结束"));
  Future((){
    return "任务3";
  }).then((value) => print("${value}结束"));
  print("任务添加完成");
}

void testFutureGroup() {
  //Futurn.wait 等任务1、任务2执行完成后，一起返回
  Future.wait([Future((){
    return "任务1";
  }),
    Future((){
      return "任务2";
    })]).then((value) => print(value[0]+value[1]));
  print("任务添加完成");
}

void testFutureAsync() {
  print("外部代码1");
  //then其实也相当于放入到了微任务队列中
  Future(()=>print('A')).then((value) => print('A结束'));
  Future(()=>print('B')).then((value) => print('B结束'));

  //微任务队列（微任务比Future异步优先级高）
  scheduleMicrotask((){
    print("微任务");
  });
  sleep(Duration(seconds: 3));
  print('外部代码2');
}

void testFutureMicro() {
  Future x1 = Future(()=>null);
  x1.then((value) {
    print('6');
    scheduleMicrotask(() => print('7'));
  }).then((value) => print('8'));
  Future x = Future(()=>print('1'));
  x.then((value) {
    print('4');
    Future(()=>print('9')).then((value) => print('10'));
  }).then((value) => print('11'));
  Future(()=>print('2'));
  scheduleMicrotask(()=>print('3'));

  print('5');
}

void testIsolate(){
  /*
  * Isolate看起来更加像一个进程,
  * 因为有独立的内存空间
  * 它的好处是：不用担心多线程的资源抢夺问题，不需要锁
  * 问题：数据交互起来比较麻烦；
  * 在真实环境中使用：创建Port
  * */
  print('外部代码1');
  Isolate.spawn(func, 100);
//  func(100);
  sleep(Duration(seconds: 1));
  print('回来之后的a${a}');
  print('外部代码2');
}

void testIsolatePort() {
  print("外部代码1");
  //创建Port
  ReceivePort port = ReceivePort();
  //创建Isolate
  Isolate.spawn(func2, port.sendPort);
  port.listen((message) {
    a = message;
    print("send回来${a}");
  });
  print("外部代码2");
}

void testIsolatePortAsync() async{
  print("外部代码1");
  //创建Port
  ReceivePort port = ReceivePort();
  //创建Isolate
  Isolate iso = await Isolate.spawn(func2, port.sendPort);
  port.listen((message) {
    a = message;
    print("send回来${a}");
    port.close();
    iso.kill();
  });
  print("外部代码2");
}

int a = 10;

void func(int count){
  a = count;
  print("第一个搞定");
  print('a现在是${a}');
}

void func2(SendPort send){
  print("第二个搞定");
  send.send(1000);
}

void computeTest() async{
  /*
  * compute是Isolate更上层封装
  * 但是能够返回数据，不需要port
  * */
  print('外部代码1');
  int x = await compute(func3, 10);
  print("返回内容后${x}");
  sleep(Duration(seconds: 1));
  print('外部代码2');
}

int func3(int count){
  a = count;
  print("第一个搞定");
  print('a现在是${a}');
  return 1000;
}
