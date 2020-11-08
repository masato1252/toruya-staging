import axios from "axios";
import safeAwait from "safe-await";

const client = axios.create();

const request = (options) => {
  return safeAwait(axios(options));
}

export default request;
