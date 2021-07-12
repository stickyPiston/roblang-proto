# Roblang-proto

Prototype for roblang in coffeescript

## Example script

```roblang
# Function declarations #
puts: (u8*) -> void;
calloc: (u8, u8) -> any*;
strncpy: (u8*, u8*, u8) -> void;
strncat: (u8*, u8*, u8) -> void;

# Implementation #
main = () -> {
  str1: u8* = calloc(20, 1);
  strncpy(str1, "Hello ", 7);

  str2 = ['W', 'a', 'r', 'l', 'd', 0];
  a = 0;
  a = a + 1;
  str2[a] = 'o';
  str3 = "?";

  strncat(str1, str2, 6);
  strncat(str1, str3, 2);
  str1[11] = '!';

  puts(str1); # Outputs "Hello World!" #

  return(0);
};
```

Compile this script with `yarn start <path to file>`
