//
//  TableViewController.swift
//  ToDoDemo
//
//  Created by WANG WEI on 2017/7/6.
//  Copyright © 2017年 OneV's Den. All rights reserved.
//

import UIKit

let inputCellReuseId = "inputCell"
let todoCellResueId = "todoCell"

class TableViewController: UITableViewController {
    
    struct State: StateType {
        var dataSource = TableViewControllerDataSource(todos: [], owner: nil)
        var text: String = ""
    }
    
    enum Action: ActionType {
        case updateText(text: String)
        case addToDos(items: [String])
        case removeToDo(index: Int)
        case loadToDos
    }
    
    enum Command: CommandType {
        case loadToDos(completion: ([String]) -> Void )
        case someOtherCommand
    }
    //这个属性会被保存到store对象的reducer属性中，其dispatch方法可以调用
    lazy var reducer: (State, Action) -> (state: State, command: Command?) = {
        [weak self] (state: State, action: Action) in
   
        var state = state
        var command: Command? = nil
        // 处理 增、删、改 action会产生新的dataSource对象
        switch action {
        case .updateText(let text):
            state.text = text
        case .addToDos(let items):
            state.dataSource = TableViewControllerDataSource(todos: items + state.dataSource.todos, owner: state.dataSource.owner)
        case .removeToDo(let index):
            var oldTodos = state.dataSource.todos
            // 这个写法牛逼了
            let currentTodos = Array(oldTodos[..<index] + oldTodos[(index + 1)...])
            state.dataSource = TableViewControllerDataSource(todos: currentTodos, owner: state.dataSource.owner)
        case .loadToDos:
            command = Command.loadToDos {
                // 数据请求完毕的回调，执行添加代办事项的action
                self?.store.dispatch(.addToDos(items: $0))
            }
        }
        return (state, command)
    }
    
    var store: Store<Action, State, Command>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let dataSource = TableViewControllerDataSource(todos: [], owner: self)
        
        store = Store<Action, State, Command>(reducer: reducer, initialState: State(dataSource: dataSource, text: ""))
        
        // 在block里调用方法必须要写上self，为了防止循环引用 需要写上 [weak self]
        store.subscribe { [weak self] (state, previousState, command) in
            // 将下面的方法 保存到store对象的subscriber中，其dispatch方法可以调用
            self?.stateDidChanged(state: state, previousState: previousState, command: command)
        }
        
        stateDidChanged(state: store.state, previousState: nil, command: nil)
        store.dispatch(.loadToDos)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // 这个方法被当做block保存到了store对象的subscriber中，dispatch方法可以调用
    func stateDidChanged(state: State, previousState: State?, command: Command?) {
        
        if let command = command {
            switch command {
            // 如果是需要加载数据的command，那么去发送网络请求
            case .loadToDos(let handler):
                ToDoStore.shared.getToDoItems(completionHandler: handler)
            case .someOtherCommand:
                // 其他Command的调用
                // Placeholder command.
                break
            }
        }
        // 如果没有状态 或者 待办事项有更新内容
        if previousState == nil || previousState!.dataSource.todos != state.dataSource.todos {
            let dataSource = state.dataSource
            tableView.dataSource = dataSource
            tableView.reloadData()
            title = "TODO - (\(dataSource.todos.count))"
        }
        
        // 如果没有状态 或者 正在填写的待办事项发生了改变
        if previousState == nil  || previousState!.text != state.text {
            let isItemLengthEnough = state.text.count >= 3
            navigationItem.rightBarButtonItem?.isEnabled = isItemLengthEnough
            
            let inputIndexPath = IndexPath(row: 0, section: TableViewControllerDataSource.Section.input.rawValue)
            let inputCell = tableView.cellForRow(at: inputIndexPath) as? TableViewInputCell
            inputCell?.textField.text = state.text
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == TableViewControllerDataSource.Section.todos.rawValue else { return }
        store.dispatch(.removeToDo(index: indexPath.row))
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        store.dispatch(.addToDos(items: [store.state.text]))
        store.dispatch(.updateText(text: ""))
    }
}

extension TableViewController: TableViewInputCellDelegate {
    func inputChanged(cell: TableViewInputCell, text: String) {
        store.dispatch(.updateText(text: text))
    }
}

