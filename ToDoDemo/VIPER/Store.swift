//
//  Store.swift
//  ToDoDemo
//
//  Created by 王 巍 on 2017/7/6.
//  Copyright © 2017年 OneV's Den. All rights reserved.
//

import Foundation

protocol ActionType {}
protocol StateType {}
protocol CommandType {}

class Store<Action: ActionType, State: StateType, Command: CommandType> {
    let reducer: (_ state: State, _ action: Action) -> (State, Command?)
    // 存储属性
    var subscriber: ((_ state: State, _ previousState: State, _ command: Command?) -> Void)?
    var state: State
    
    init(reducer: @escaping (State, Action) -> (State, Command?), initialState: State) {
        self.reducer = reducer
        self.state = initialState
    }
    
    func subscribe(Handler handler: @escaping (State, State, Command?) -> Void) {
        // 在这里 将订阅者保存起来，以供后面 dispatch 方法使用
        self.subscriber = handler
    }
    
    func unsubscribe() {
        self.subscriber = nil
    }
    
    func dispatch(_ action: Action) {
        let previousState = state
        //通过reducer 传入之前的state和action，输出下一步的state和command
        let (nextState, command) = reducer(state, action)
        state = nextState
        subscriber?(state, previousState, command)
    }
}

