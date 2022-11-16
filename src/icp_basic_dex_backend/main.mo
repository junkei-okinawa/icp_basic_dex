import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";

import BalanceBook "balance_book";
import T "types";

actor class Dex() = this {

  // DEXのユーザートークンを管理するモジュール
  private var balance_book = BalanceBook.BalanceBook();

  // ===== DEPOSIT / WITHDRAW =====
  // ユーザーがDEXにトークンを預ける時にコールする
  // 成功すると預けた量を、失敗するとエラー文を返す
  public shared (msg) func deposit(token : T.Token) : async T.DepositReceipt {
    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;

    // トークンに設定された`fee`を取得
    let dip_fee = await fetch_dif_fee(token);

    // ユーザーが保有するトークン量を取得
    let balance = await dip20.allowance(msg.caller, Principal.fromActor(this));
    if (balance <= dip_fee) {
      return #Err(#BalanceLow);
    };

    // DEXに転送
    let token_reciept = await dip20.transferFrom(msg.caller, Principal.fromActor(this), balance - dip_fee);
    switch token_reciept {
      case (#Err e) return #Err(#TransferFailure);
      case _ {};
    };

    // `balance_book`にユーザーPrincipalとトークンデータを記録
    balance_book.addToken(msg.caller, token, balance - dip_fee);

    return #Ok(balance - dip_fee);
  };

  // DEXからトークンを引き出す時にコールされる
  // 成功すると引き出したトークン量が、失敗するとエラー文を返す
  public shared (msg) func withdraw(token : T.Token, amount : Nat) : async T.WithdrawReceipt {
    if (balance_book.hasEnoughBalance(msg.caller, token, amount) == false) {
      return #Err(#BalanceLow); 
    };

    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;

    // `transfer`でユーザーにトークンを転送する
    let txReceipt = await dip20.transfer(msg.caller, amount);
    switch txReceipt {
      case (#Err e) return #Err(#TransferFailure);
      case _ {};
    };

    let dip_fee = await fetch_dif_fee(token);

    // `balance_book`のトークンデータを修正する
    switch (balance_book.removeToken(msg.caller, token, amount + dip_fee)) {
      case null return #Err(#BalanceLow);
      case _ {};
    };
  
    return #Ok(amount);
  };

  // ===== INTERNAL FUNCTIONS =====
  // トークンに設定された`fee`を取得する
  private func fetch_dif_fee(token : T.Token) : async Nat {
    let dip20 = actor (Principal.toText(token)) : T.DIPInterface;
    let metadata = await dip20.getMetadata();
    return (metadata.fee);
  };

  // ===== DEX STATE FUNCTIONS =====
  // 引数で渡されたトークンPrincipalの残高を取得する
  public shared query (msg) func getBalance(token : T.Token) : async Nat {
    // ユーザーのデータがあるかどうか
    switch (balance_book.get(msg.caller)) {
      case null return 0;
      case (?token_balances) {
        // トークンのデータがあるかどうか
        switch (token_balances.get(token)) {
          case null return (0);
          case (?amount) {
            return (amount);
          };
        };
      };
    };
  };
};