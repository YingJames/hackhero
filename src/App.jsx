import './styles/App.css';
import { BrowserRouter as Router, Route, Routes } from "react-router-dom";
import SignIn from './components/SignIn';
import SignUp from "./components/SignUp";

export default function App() {
  return (
      <Router>
        <Routes>
          <Route path="/" element={<SignIn />} />
          <Route path="/sign-in" element={<SignIn />} />
          <Route path="/sign-up" element={<SignUp />} />

          <Route path="*" element={<SignIn />} />
        </Routes>
      </Router>
  )
}
