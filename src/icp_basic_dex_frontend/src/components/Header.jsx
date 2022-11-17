import React from 'react';
import { AuthClient } from '@dfinity/auth-client';
import { HttpAgent } from '@dfinity/agent';
import { canisterId as IICanisterID }
  from '../../../declarations/internet_identity_div';

export const Header = (props) => {
  const {
    setUserPrincipal,
  } = props;

  const handleSuccess = async (authClient) => {
    // 認証したユーザーの`identity`を取得
    const identity = await authClient.getIdentity();

    // 認証したユーザーの`principal`を取得
    const principal = identity.getPrincipal();
    setUserPrincipal(principal);

    console.log(`User Principal: ${principal.toString()}`);
  };

  const handleLogin = async () => {
    // アプリケーションが接続しているネットワークに応じて、
    // ユーザー認証に使用するInternet IdentityのURLを決定する
    let iiUrl;
    if (process.env.DFX_NETWORK === "local") {
      iiUrl = `http://localhost:8000/?canisterId=${IICanisterID}`;
    } else if (process.env.DFX_NETWORK === "ic") {
      iiUrl = 'https://identity.ic0.app/#authorize';
    } else {
      iiUrl = `https://${IICanisterID}.dfinity.network`;
    }
    // ログイン認証を実行
    const authClient = await AuthClient.create();
    authClient.login({
      identityProvider: iiUrl,
      onSuccess: async () => {
        handleSuccess(authClient);
      },
      onError: (error) => {
        console.error(`Login Failed: , ${error}`);
      }
    })
  };

  return (
    <ul>
      <li>SIMPLE DEX</li>
      <li className='btn-login'>
        <button
          onClick={handleLogin}>
          Login Internet Identity
        </button>
      </li>
    </ul>
  )
}