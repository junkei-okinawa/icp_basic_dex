import React from 'react';
import './App.css';

import { Header } from './components/Header';

const App = () => {
  const [userPrincipal, setUserPrincipal] = useState();

  return (
    <>
      <Header
        setUserPrincipal={setUserPrincipal}
      />
      {/* ログイン認証していない時 */}
      {!userPrincipal &&
        <div className='title'>
          <h1>Welcome!</h1>
          <h2>Please push the login button.</h2>
        </div>
      }
    </>
  )
};

export default App;