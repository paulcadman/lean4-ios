#include <Foundation/Foundation.h>
#include <lean/lean.h>

static lean_obj_res lean_tfl_error(const char *message) {
  return lean_io_result_mk_error(lean_mk_io_user_error(lean_mk_string(message)));
}

lean_obj_res lean_http_fetch_body(b_lean_obj_arg url_arg) {
  @autoreleasepool {
    NSString *urlString = [NSString stringWithUTF8String:lean_string_cstr(url_arg)];
    if (urlString == nil) {
      return lean_tfl_error("invalid URL string");
    }

    NSURL *url = [NSURL URLWithString:urlString];
    if (url == nil) {
      return lean_tfl_error("could not construct URL");
    }

    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:&error];
    if (data == nil) {
      const char *message = error != nil ? error.localizedDescription.UTF8String : "network request failed";
      return lean_tfl_error(message);
    }

    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (json == nil) {
      return lean_tfl_error("response was not valid UTF-8");
    }

    return lean_io_result_mk_ok(lean_mk_string(json.UTF8String));
  }
}
