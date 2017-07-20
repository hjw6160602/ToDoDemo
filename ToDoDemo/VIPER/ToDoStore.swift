//
//  ToDoStore.swift
//  ToDoDemo
//
//  Created by 王 巍 on 2017/7/6.
//  Copyright © 2017年 OneV's Den. All rights reserved.
//

import Foundation

let dummy = [
    "Buy the milk",
    "Take my dog",
    "Rent a car"
]

struct ToDoStore {
    // 结构体单例
    static let shared = ToDoStore()
    //在这里模拟 网络请求，在2秒之后返回网路数据
    func getToDoItems(completionHandler: (([String]) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completionHandler?(dummy)
        }
    }
}
