/// 协议层共享的版本与大小限制。
const int protocolSchemaVersion = 1;

/// 单条消息的 UTF-8 字节上限（64 KiB）。
const int maxProtocolMessageBytes = 64 * 1024;

/// 签名域分离前缀，防止本协议的签名被其他协议重放。
const String signatureDomainPrefix = 'PeerServe:v1:';
