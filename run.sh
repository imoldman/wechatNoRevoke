clang -dynamiclib main.m -fobjc-link-runtime -current_version 1.0 -compatibility_version 1.0 -o wechat_no_revoke.A.dylib
if [ "$?" -eq "0" ]; then
  DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  DYLD_INSERT_LIBRARIES=${DIR}/wechat_no_revoke.A.dylib /Applications/WeChat.app/Contents/MacOS/WeChat
fi
