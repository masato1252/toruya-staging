import axios from "axios";

const COMPAT_API_PREFIX = "/v1/compat";

const EXCLUDED_PATH_PREFIXES = ["/stripe_", "/api/images"];

const COMPAT_PATH_PREFIXES = ["/lines/", "/surveys/", "/customer_verification/"];

let compatAxiosConfigured = false;
let compatFetchInstalled = false;

function readCompatApiOrigin() {
  const meta = document.querySelector('meta[name="compat-api-origin"]');
  if (!meta || !meta.content) return null;
  return meta.content.replace(/\/$/, "");
}

function isExcludedPath(pathname) {
  return EXCLUDED_PATH_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

function isCompatCandidatePath(pathname) {
  if (COMPAT_PATH_PREFIXES.some((prefix) => pathname.startsWith(prefix))) return true;
  if (pathname.startsWith("/online_services/")) return true;
  return false;
}

export function compatApiPath(relativePath) {
  const path = relativePath.startsWith("/") ? relativePath : `/${relativePath}`;
  if (path === COMPAT_API_PREFIX || path.startsWith(`${COMPAT_API_PREFIX}/`)) {
    return path;
  }
  return `${COMPAT_API_PREFIX}${path}`;
}

function extractPathname(url) {
  if (typeof url !== "string") return null;

  if (url.startsWith("http://") || url.startsWith("https://")) {
    try {
      const parsed = new URL(url);
      if (parsed.origin !== window.location.origin) return null;
      return parsed.pathname;
    } catch (_error) {
      return null;
    }
  }

  if (url.startsWith("/")) {
    const cutIndex = url.search(/[?#]/);
    return cutIndex === -1 ? url : url.slice(0, cutIndex);
  }

  return null;
}

function extractSuffix(url) {
  if (typeof url !== "string" || !url.startsWith("/")) return "";
  const cutIndex = url.search(/[?#]/);
  return cutIndex === -1 ? "" : url.slice(cutIndex);
}

function getRequestHeaders(input, init) {
  const headers = new Headers();

  if (input instanceof Request) {
    input.headers.forEach((value, key) => headers.set(key, value));
  }

  if (init && init.headers) {
    new Headers(init.headers).forEach((value, key) => headers.set(key, value));
  }

  return headers;
}

function getRequestMethod(input, init) {
  if (init && init.method) return init.method.toUpperCase();
  if (input instanceof Request) return input.method.toUpperCase();
  return "GET";
}

export function shouldRewriteCompatRequest(url, input, init) {
  if (!readCompatApiOrigin()) return false;

  const pathname = extractPathname(url);
  if (!pathname || isExcludedPath(pathname)) return false;
  if (!isCompatCandidatePath(pathname)) return false;

  const headers = getRequestHeaders(input, init);
  const accept = (headers.get("Accept") || "").toLowerCase();
  const contentType = (headers.get("Content-Type") || "").toLowerCase();
  const method = getRequestMethod(input, init);

  if (pathname.includes(".json")) return true;
  if (accept.includes("application/json")) return true;
  if (contentType.includes("application/json")) return true;
  if (method !== "GET" && method !== "HEAD") return true;

  if (method === "GET" && headers.get("X-Requested-With") === "XMLHttpRequest") {
    if (!accept.includes("application/json") && !pathname.includes(".json")) {
      return false;
    }
  }

  if (method === "GET" && !accept.includes("text/html")) return true;

  return false;
}

export function rewriteCompatUrl(url, input, init) {
  const origin = readCompatApiOrigin();
  if (!origin || typeof url !== "string") return url;
  if (!shouldRewriteCompatRequest(url, input, init)) return url;

  const pathname = extractPathname(url);
  if (!pathname) return url;

  const compatPath = compatApiPath(pathname);
  const suffix = extractSuffix(url);

  if (url.startsWith("http://") || url.startsWith("https://")) {
    try {
      const parsed = new URL(url);
      return `${origin}${compatPath}${parsed.search}${parsed.hash}`;
    } catch (_error) {
      return url;
    }
  }

  return `${origin}${compatPath}${suffix}`;
}

function withCredentialsInit(init) {
  if (!readCompatApiOrigin()) return init;
  return { credentials: "include", ...init };
}

const nativeFetch = window.fetch.bind(window);

export function installCompatFetch() {
  if (compatFetchInstalled) return;
  compatFetchInstalled = true;

  window.fetch = (input, init) => {
    if (typeof input === "string") {
      const rewritten = rewriteCompatUrl(input, input, init);
      return nativeFetch(rewritten, withCredentialsInit(init));
    }

    if (input instanceof Request) {
      const rewritten = rewriteCompatUrl(input.url, input, init);
      if (rewritten === input.url) return nativeFetch(input, init);

      const request = new Request(rewritten, input);
      return nativeFetch(request, withCredentialsInit(init));
    }

    return nativeFetch(input, init);
  };
}

export function configureCompatAxios() {
  if (compatAxiosConfigured) return;
  compatAxiosConfigured = true;

  axios.defaults.withCredentials = true;
  axios.interceptors.request.use((config) => {
    if (config.url) {
      config.url = rewriteCompatUrl(config.url, config.url, config);
    }
    return config;
  });
}

export function installCompatApi() {
  configureCompatAxios();
  installCompatFetch();
}
