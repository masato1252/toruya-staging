import React, { useState, useEffect } from "react";
import postal_code from "japan-postal-code";

const useAddress = (code) => {
  const [address, setAddress] = useState({})

  useEffect(() => {
    if (code && code.length >= 7) {
      postal_code.get(code, (address) => {
        console.log("address", address)
        setAddress(address)
      });
    }
  }, [code])

  return address;
}

export default useAddress;
