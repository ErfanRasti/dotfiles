--!nonstrict
-- MD5 (RFC 1321) of a string, as 32 lowercase hex digits. Thumbnail caches name
-- each file by the MD5 of its URI (freedesktop thumbnail spec), and Luau has none.
--
-- Part of the dotfiles, under the repo's GPL-3.0 license (LICENSE at the repo root).

local band, bor, bxor, bnot, lrotate = bit32.band, bit32.bor, bit32.bxor, bit32.bnot, bit32.lrotate

local S = {
  7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
  5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20,
  4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
  6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
}

local K = {}
for i = 1, 64 do
  K[i] = math.floor(math.abs(math.sin(i)) * 2 ^ 32) % 2 ^ 32
end

local function md5(msg)
  local len = #msg
  local bits = len * 8
  -- Pad: 0x80, zeros to 56 mod 64, then the bit length as 64-bit little endian.
  msg = msg .. "\128" .. string.rep("\0", (55 - len) % 64)
    .. string.char(bits % 256, (bits // 256) % 256, (bits // 65536) % 256, (bits // 16777216) % 256)
    .. string.char((bits // 2 ^ 32) % 256, (bits // 2 ^ 40) % 256, (bits // 2 ^ 48) % 256, (bits // 2 ^ 56) % 256)

  local a0, b0, c0, d0 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
  local M = {}
  for chunk = 1, #msg, 64 do
    for i = 0, 15 do
      local p = chunk + i * 4
      local w0, w1, w2, w3 = string.byte(msg, p, p + 3)
      M[i] = w0 + w1 * 256 + w2 * 65536 + w3 * 16777216
    end
    local a, b, c, d = a0, b0, c0, d0
    for i = 0, 63 do
      local f, g
      if i < 16 then
        f, g = bor(band(b, c), band(bnot(b), d)), i
      elseif i < 32 then
        f, g = bor(band(d, b), band(bnot(d), c)), (5 * i + 1) % 16
      elseif i < 48 then
        f, g = bxor(b, c, d), (3 * i + 5) % 16
      else
        f, g = bxor(c, bor(b, bnot(d))), (7 * i) % 16
      end
      f = (f + a + K[i + 1] + M[g]) % 2 ^ 32
      a, d, c = d, c, b
      b = (b + lrotate(f, S[i + 1])) % 2 ^ 32
    end
    a0, b0, c0, d0 = (a0 + a) % 2 ^ 32, (b0 + b) % 2 ^ 32, (c0 + c) % 2 ^ 32, (d0 + d) % 2 ^ 32
  end

  local out = {}
  for _, word in ipairs({ a0, b0, c0, d0 }) do
    for _ = 1, 4 do
      table.insert(out, string.format("%02x", word % 256))
      word = word // 256
    end
  end
  return table.concat(out)
end

return md5
