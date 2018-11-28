//
//  SocketConnection.swift
//  TeenPatti
//
//  Created by Vnnovate on 21/09/18.
//  Copyright © 2018 Vnnovate. All rights reserved.
//

import UIKit
import SocketIO

protocol SocketConnectionDelegate: class {
    func socketEmitResponseData(data: NSDictionary, sequenceType: Sequence)
    func socketError(error: String, sequenceType: Sequence)
    func socketNotifyResponseData(data: NSDictionary, notifyType: Notify)
}


class SocketConnection: NSObject {
    
    static let manager = SocketManager(socketURL: URL(string: Constant.baseUrl)!, config: [.log(false), .compress])
    static let socket = manager.defaultSocket
    weak var delegate: SocketConnectionDelegate?
    
    class var sharedInstance : SocketConnection {
        struct Static {
            static let instance : SocketConnection = SocketConnection()
        }
        return Static.instance
    }
    
    func connectSocket() {
        SocketConnection.socket.connect()
    }
    
    func disconnectSocket(){
        SocketConnection.socket.disconnect()
    }
    
    func socketHandler() {
        
        SocketConnection.socket.on(clientEvent: .connect) {data, ack in
            print("---------------------socket connected-----------------")
            
            print("Login request from Socket handler")
            let userdefault = UserDefaults.standard
            if let isremember = userdefault.value(forKey: Userdefaults.remember.keyName()) as? Bool, isremember, let uid = userdefault.value(forKey: Userdefaults.uid.keyName()) as? String, let pass = userdefault.value(forKey: Userdefaults.password.keyName()) as? String {
                print("---------------------Auto login-----------------")
                self.loginRequest(uid, password: pass)
            }else {
                let uid = userdefault.value(forKey: Userdefaults.uid.keyName()) as? String ?? ""
                let pass = userdefault.value(forKey: Userdefaults.password.keyName()) as? String ?? ""
                self.loginRequest(uid, password: pass)
            }
        }
        
        SocketConnection.socket.on(clientEvent: .disconnect) {data, ack in
            print("-----------------------socket disconnect------------------")
            self.connectSocket()
        }
        
        SocketConnection.socket.on(Constant.rpc_ret) {[weak self] data, ack in
            self?.handleEmitData(data)
            return
        }
        
        SocketConnection.socket.on(Constant.notify) {[weak self] data, ack in
            print("-----------------------socket notify-----------------------")
            self?.handleNotifyData(data)
        }
    }
    
    // Common Emit request function
    fileprivate func emitRequest<T>(seq: Sequence, constant: String, args: T) {
        print("==============Socket \(seq.name()) Request=========================")
        
        let userdefualt = UserDefaults.standard
        let pin = userdefualt.value(forKey: Userdefaults.pin.keyName()) as? Int ?? 00
        let uid = userdefualt.value(forKey: Userdefaults.uid.keyName()) as? String ?? ""
        print("Pin =====>", pin, "UID =====>", uid, "With T =>", args)
        
        let emitDic = [
            "seq" : seq.name(),
            "uid" : uid,
            "pin" : pin,
            "f" : constant,
            "args": args] as Dictionary<String, Any>
        print("Emit Dictionay ===>", emitDic)
        SocketConnection.socket.emit(Constant.rpc, emitDic)
    }
    
    func loginRequest(_ username:String, password: String, isRemember: Bool = true) {
        
        let loginInfo = [
            "uid" : username,
            "passwd" : password
        ]
        
        let logindata = [
            "seq" : Sequence.login.name(),
            "uid" : 0,
            "pin" : 0,
            "f" : "login",
            "args": loginInfo] as Dictionary<String, Any>
        print("Login info =====>", logindata)
        SocketConnection.socket.emit(Constant.rpc, logindata)
        
    }
    
    func getRoomDataRequest(_ gametype: String) {
        self.emitRequest(seq: Sequence.rooms, constant: Constant.room, args: gametype)
    }
    
    func enterRoomRequest(_ args: Int) {
        self.emitRequest(seq: Sequence.enterroom, constant: Constant.enterroom, args: args)
    }
    
    func enterGameRequest(_ args: String) {
        
        self.emitRequest(seq: Sequence.entergame, constant: Constant.entergame, args: args)
    }
    
    func readyRequest(_ delegate: SocketConnectionDelegate?) {
        self.delegate = delegate
        self.emitRequest(seq: Sequence.ready, constant: Constant.ready, args: "0")
    }
    
    func leaveRequest() {
        self.standUpFromTable()
        self.emitRequest(seq: Sequence.leave, constant: Constant.leave, args: "0")
    }
    
    func logoutRequest() {
        self.emitRequest(seq: Sequence.logout, constant: Constant.logout, args: "0")
    }
    
    func raiseRequest(_ amount: Int) {
        self.emitRequest(seq: Sequence.raise, constant: Constant.raise, args: amount)
    }
    
    func packRequest() {
        self.emitRequest(seq: Sequence.fold, constant: Constant.fold, args: "0")
    }
    
    func seeCards() {
        self.emitRequest(seq: Sequence.seecard, constant: Constant.showcard, args: "0")
    }
    
    func showCards(raiseAmt: Int) {
        self.emitRequest(seq: Sequence.show, constant: Constant.show, args: raiseAmt)
    }
    
    func userdataRequest() {
        let userdefualt = UserDefaults.standard
        let pin = userdefualt.value(forKey: Userdefaults.pin.keyName()) as? Int ?? 00
        let uid = userdefualt.value(forKey: Userdefaults.uid.keyName()) as? String ?? ""
        print("Pin =====>", pin, "UID =====>", uid)
        
        let userdata = [
            "seq" : Sequence.userdata.name(),
            "uid" : uid,
            "pin" : pin,
            "f" : Constant.userdata] as Dictionary<String, Any>
        print("Userdata info =====>", userdata)
        SocketConnection.socket.emit(Constant.rpc, userdata)
    }
    
    func sideShowRequest(_ prevuseruid: String, raiseAmount:Int) {
        self.emitRequest(seq: Sequence.pkrequest, constant: Constant.pkrequest, args: prevuseruid)
    }
    
    func sideShowAccept(_ prevuseruid: String) {
        self.emitRequest(seq: Sequence.pk, constant: Constant.pk, args: prevuseruid)
    }
    
    func sideShowDecline(_ prevuseruid: String) {
        let userdefualt = UserDefaults.standard
        let pin = userdefualt.value(forKey: Userdefaults.pin.keyName()) as? Int ?? 0
        let uid = userdefualt.value(forKey: Userdefaults.uid.keyName()) as? String ?? ""
        print("Pin =====>", pin, "UID =====>", uid)
        
        let sideshowdecline = [
            "seq" : Sequence.pkdecline.name(),
            "uid" : prevuseruid,
            "pin" : pin,
            "f" : Constant.pkdecline,
            "args": uid] as Dictionary<String, Any>
        print("sideShowDecline ===>", sideshowdecline)
        SocketConnection.socket.emit(Constant.rpc, sideshowdecline)
    }
    
    func standUpFromTable() {
        self.emitRequest(seq: Sequence.unseat, constant: Constant.unseat, args: "0")
    }
    
    
    // MARK: - Handle Notify Data
    fileprivate func handleNotifyData(_ data: [Any]) {
        
        //print("============Socket Notify data========", data.first ?? "-----")
        
        if let data = data.first as? NSDictionary {
            
            let notifyName = data.value(forKey: "e") as? String ?? ""
            print("============Socket Notify event========", notifyName)
            
            switch notifyName {
            case Notify.look.name():
                self.notifyResponse(data, notifyType: .look)
            case Notify.ready_gamers.name():
                self.notifyResponse(data, notifyType: .ready_gamers)
            case Notify.ready_countdown.name():
                self.notifyResponse(data, notifyType: .ready_countdown)
            case Notify.gamestart.name():
                self.notifyResponse(data, notifyType: .gamestart)
            case Notify.moveturn.name():
                self.notifyResponse(data, notifyType: .moveturn)
            case Notify.countdown.name():
                self.countdownNotify(data)
            case Notify.raise.name():
                self.notifyResponse(data, notifyType: .raise)
            case Notify.show.name():
                self.notifyResponse(data, notifyType: .show)
            case Notify.showcard.name():
               self.notifyResponse(data, notifyType: .showcard)
            case Notify.seecard.name():
                self.notifyResponse(data, notifyType: .seecard)
            case Notify.pkrequest.name():
                self.notifyResponse(data, notifyType: .pkrequest)
            case Notify.pk.name():
                self.notifyResponse(data, notifyType: .pk)
            case Notify.pkdecline.name():
                self.notifyResponse(data, notifyType: .pkdecline)
            case Notify.fold.name():
                self.notifyResponse(data, notifyType: .fold)
            case Notify.gameover.name():
                self.gameoverNotify(data)
            case Notify.bye.name():
                self.byeNotify(data)
            default:
                break
            }
            
        }else {
            self.delegate?.socketError(error: "Something went to wrong", sequenceType: .none)
        }
    }
    
    // MARK: - Handle Emit Data (rpc_ret)
    fileprivate func handleEmitData(_ data: [Any]) {
        
        if let data = data.first as? NSDictionary {
            
            let sequncename = data.value(forKey: "seq") as? String ?? ""
            print("================> Socket response Emit====>", sequncename)
            
            switch sequncename {
            case Sequence.login.name():
                self.loginProcess(data)
            case Sequence.rooms.name():
                self.roomsProcess(data)
            case Sequence.enterroom.name():
                self.enterRoomsProcess(data)
            case Sequence.entergame.name():
                self.enterGameProcess(data)
            case Sequence.ready.name():
                self.readyProcess(data)
            case Sequence.leave.name():
                self.leaveProcess(data)
            case Sequence.raise.name():
                self.raiseProcess(data)
            case Sequence.userdata.name():
                self.userdataProcess(data)
            case Sequence.fold.name():
                self.foldProcess(data)
            case Sequence.logout.name():
                self.logoutProcess(data)
            default:
                break
            }
            
        }else {
            self.delegate?.socketError(error: "Something went to wrong", sequenceType: .none)
        }
    }
    
    // MARK: - Process data and send response to delegate
    
    fileprivate func loginProcess(_ data: NSDictionary) {
        
        if data.value(forKey: "err") as? Int == 0, let retdata = data.value(forKey: "ret") as? [AnyHashable: Any], let profiledata = retdata["profile"] as? [String: Any], let token = retdata["token"] as? [String: Any]{
            
            let username = profiledata["name"] as? String ?? ""
            let score = profiledata["score"] as? String ?? "00"
            let coins = profiledata["coins"] as? String ?? "00"
            let level = profiledata["level"] as? String ?? "00"
            let uid = profiledata["uid"] as? String ?? ""
            let pin = token["pin"] as? Int ?? 00
            
            let userdefault = UserDefaults.standard
            userdefault.set(username, forKey: Userdefaults.username.keyName())
            userdefault.set(score, forKey: Userdefaults.score.keyName())
            userdefault.set(coins, forKey: Userdefaults.coin.keyName())
            userdefault.set(level, forKey: Userdefaults.level.keyName())
            userdefault.set(uid, forKey: Userdefaults.uid.keyName())
            userdefault.set(true, forKey: Userdefaults.login.keyName())
            userdefault.set(pin, forKey: Userdefaults.pin.keyName())
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .login)
            
        }else {
            self.delegate?.socketError(error: "Please enter valid username and password.", sequenceType: .login)
        }
    }
    
    fileprivate func enterGameProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .entergame)
        }else {
            self.delegate?.socketError(error: data.value(forKey: "ret") as? String ?? "", sequenceType: .entergame)
        }
    }
    
    fileprivate func readyProcess(_ data: NSDictionary) {
        print("delegate ===>", self.delegate ?? "---")
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .ready)
        }else if data["err"] as? Int == 400,  let error =  data["ret"] as? String {
            self.delegate?.socketError(error: error, sequenceType: .ready)
        }else if data["err"] as? Int == 402 {
            self.delegate?.socketError(error: "402", sequenceType: .ready)
        }
    }
    
    fileprivate func leaveProcess(_ data: NSDictionary) {
        self.delegate?.socketEmitResponseData(data: data, sequenceType: .leave)
    }
    
    fileprivate func raiseProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .raise)
        }else {
            self.delegate?.socketError(error: "error", sequenceType: .raise)
        }
    }
    
    fileprivate func roomsProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .rooms)
        }else {
            self.delegate?.socketError(error: "error", sequenceType: .rooms)
        }
    }
    
    fileprivate func enterRoomsProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .enterroom)
        }else {
            self.delegate?.socketError(error: "error", sequenceType: .enterroom)
        }
    }
    
    fileprivate func userdataProcess(_ data: NSDictionary) {
        print(delegate ?? "----")
        if data.value(forKey: "err") as? Int == 0, let profiledata = data["profile"] as? NSDictionary {
            self.delegate?.socketEmitResponseData(data: profiledata, sequenceType: .userdata)
        }else {
            self.delegate?.socketError(error: "Error", sequenceType: .userdata)
        }
    }
    
    fileprivate func foldProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .fold)
        }else {
            self.delegate?.socketError(error: "error", sequenceType: .fold)
        }
    }
    
    fileprivate func logoutProcess(_ data: NSDictionary) {
        if data.value(forKey: "err") as? Int == 0 {
            self.delegate?.socketEmitResponseData(data: data, sequenceType: .logout)
        }else {
            self.delegate?.socketError(error: data["ret"] as? String ?? "Error", sequenceType: .logout)
        }
    }
    
    // MARK: - All Notify response to delegate
    
    // Get Seconds for progressbar
    fileprivate func countdownNotify(_ data: NSDictionary) {
        self.delegate?.socketNotifyResponseData(data: data, notifyType: .countdown)
    }
    
    // Common notify response function
    fileprivate func notifyResponse(_ data: NSDictionary, notifyType: Notify) {
        if let args = data["args"] as? NSDictionary {
            self.delegate?.socketNotifyResponseData(data: args, notifyType: notifyType)
        }else {
            self.delegate?.socketError(error: "Error", sequenceType: .none)
        }
    }
    
    fileprivate func gameoverNotify(_ data: NSDictionary) {
        self.delegate?.socketNotifyResponseData(data: data, notifyType: .gameover)
    }
    
    fileprivate func byeNotify(_ data: NSDictionary) {
        let uid = data["uid"] as? String ?? ""
        
        guard uid.isEqualto(Design.uid()) else { return }
        
        let message = data["args"] as? String ?? ""
        
        if message.isEqualto("replaced by another login") {
            self.showAlertMessage(isShowPopup: true)
        }
    }
    
    fileprivate func showAlertMessage(isShowPopup: Bool = false) {
        
        let appdelegate = UIApplication.shared.delegate
        let rootviewcontroller = appdelegate?.window??.rootViewController
        
        guard let viewcontroller = rootviewcontroller else {
            return
        }
        
        let alertmsg = UIAlertController(title: "Attention", message: "Someone has logged into your account.", preferredStyle: .alert)
        
        let okaction = UIAlertAction(title: "Ok", style: .default) { (_) in
            let mainStroyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = mainStroyboard.instantiateViewController(withIdentifier: "loginVC") as! LoginVC
            let navigation = UINavigationController(rootViewController: loginVC)
            loginVC.isLogout = false
            Design.Logout()
            appdelegate?.window??.rootViewController = navigation
        }
        
        alertmsg.addAction(okaction)

        viewcontroller.present(alertmsg, animated: true, completion: nil)
    }
}
