/**
 * LocalStorage utility with expiration support
 */

export class LocalStorageManager {
  /**
   * Store data with expiration time
   * @param {string} key - Storage key
   * @param {any} data - Data to store
   * @param {number} expirationMinutes - Expiration time in minutes
   */
  static setWithExpiry(key, data, expirationMinutes) {
    const expiryTime = new Date().getTime() + (expirationMinutes * 60 * 1000);
    const item = {
      value: data,
      expiry: expiryTime
    };
    localStorage.setItem(key, JSON.stringify(item));
  }

  /**
   * Get data and check if it's expired
   * @param {string} key - Storage key
   * @returns {any|null} - Stored data or null if expired/not found
   */
  static getWithExpiry(key) {
    try {
      const itemStr = localStorage.getItem(key);
      if (!itemStr) return null;

      const item = JSON.parse(itemStr);
      const now = new Date().getTime();

      if (now > item.expiry) {
        // If expired, remove the item
        localStorage.removeItem(key);
        return null;
      }

      return item.value;
    } catch (e) {
      console.error('Error reading from localStorage:', e);
      return null;
    }
  }

  /**
   * Remove item from storage
   * @param {string} key - Storage key
   */
  static remove(key) {
    localStorage.removeItem(key);
  }

  /**
   * Check if item exists and is not expired
   * @param {string} key - Storage key
   * @returns {boolean}
   */
  static hasValidItem(key) {
    return this.getWithExpiry(key) !== null;
  }
}