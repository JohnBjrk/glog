import gleam/erlang/atom.{Atom}
import gleam/map.{Map}
import gleam/list
import gleam/dynamic.{Dynamic}
import glog/arg.{Arg, Args}
import glog/field.{Field, Fields}
import glog/config.{Config}
import glog/level.{
  Alert, ConfigLevel, Critical, Debug, Emergency, Error, Info, Level, Notice,
  Warning,
}

/// A Gleam implementation of Erlang logger
/// Glog is the current "state" of the log to print
pub opaque type Glog {
  Glog(fields: Map(Atom, Dynamic))
}

/// Initializes a new Glog representation
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
///
/// let logger: Glog = glog.new()
/// ```
pub fn new() -> Glog {
  Glog(fields: map.new())
}

/// Adds a key/value to the current log
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
///
/// let logger: Glog = glog.new()
/// logger
/// |> add("foo", "bar")
/// |> add("woo", "zoo")
/// ```
pub fn add(logger: Glog, key: String, value: any) -> Glog {
  Glog(
    logger.fields
    |> map.insert(atom.create_from_string(key), dynamic.from(value)),
  )
}

/// Adds a Field to the current log
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
/// import glog/field
///
/// let logger: Glog = glog.new()
/// logger
/// |> add_field(field.new("foo", "bar"))
/// ```
pub fn add_field(logger: Glog, f: Field) -> Glog {
  Glog(
    logger.fields
    |> map.insert(atom.create_from_string(field.key(f)), field.value(f)),
  )
}

/// Adds Fields to the current log
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
/// import glog/field
///
/// let logger: Glog = glog.new()
/// logger
/// |> add_fields([field.new("foo", "bar"), field.new("woo", "zoo")])
/// ```
pub fn add_fields(logger: Glog, f: Fields) -> Glog {
  Glog(fields: map.merge(logger.fields, fields_to_dynamic(f)))
}

/// Prints Emergency log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
///
/// let logger: Glog = glog.new()
/// logger
/// |> emergency("er")
/// ```
pub fn emergency(logger: Glog, message: String) -> Glog {
  log(logger, Emergency, message)
}

/// Prints Emergency log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
///
/// ### Usage
/// ```gleam
/// import glog.{Glog}
///
/// let logger: Glog = glog.new()
/// logger
/// |> emergencyf("~p is the new ~p", [arg.new("foo"), arg.new("bar")])
/// ```
pub fn emergencyf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Emergency, string, values)
}

/// Prints Alert log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn alert(logger: Glog, message: String) -> Glog {
  log(logger, Alert, message)
}

/// Prints Alert log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn alertf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Alert, string, values)
}

/// Prints Critical log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn critical(logger: Glog, message: String) -> Glog {
  log(logger, Critical, message)
}

/// Prints Critical log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn criticalf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Critical, string, values)
}

/// Prints Error log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn error(logger: Glog, message: String) -> Glog {
  log(logger, Error, message)
}

/// Prints Error log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn errorf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Error, string, values)
}

/// Prints Warning log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn warning(logger: Glog, message: String) -> Glog {
  log(logger, Warning, message)
}

/// Prints Warning log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn warningf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Warning, string, values)
}

/// Prints Info log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn info(logger: Glog, message: String) -> Glog {
  log(logger, Info, message)
}

/// Prints Info log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn infof(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Info, string, values)
}

/// Prints Notice log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn notice(logger: Glog, message: String) -> Glog {
  log(logger, Notice, message)
}

/// Prints Notice log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn noticef(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Notice, string, values)
}

/// Prints Debug log with current fields stored and the given message
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn debug(logger: Glog, message: String) -> Glog {
  log(logger, Debug, message)
}

/// Prints Debug log with current fields stored and the given message template and values
///
/// Calling this function return a new Glog. Old Glog can still be used.
pub fn debugf(logger: Glog, string: String, values: Args) -> Glog {
  logf(logger, Debug, string, values)
}

// Private function handling the print logic for any level
fn log(logger: Glog, level: Level, message: String) -> Glog {
  let new_logger =
    logger
    |> add("msg", message)
  log_string_with_fields(level, new_logger.fields)

  Glog(fields: map.new())
}

// Private function handling the printf logic for any level
fn logf(logger: Glog, level: Level, string: String, values: Args) -> Glog {
  log(logger, level, sprintf(string, args_to_dynamic(values)))
}

// Transforms Args to a Dynamic list
fn args_to_dynamic(args: Args) -> List(Dynamic) {
  args
  |> list.map(fn(a) { dynamic.from(arg.value(a)) })
}

// Transforms Fields to a Atom/Dynamic map
fn fields_to_dynamic(fields: Fields) -> Map(Atom, Dynamic) {
  map.from_list(
    fields
    |> list.map(fn(f) {
      #(atom.create_from_string(field.key(f)), field.value(f))
    }),
  )
}

/// Sets log level for primary handler
pub fn set_primary_log_level(level: ConfigLevel) {
  set_primary_config_value(
    atom.create_from_string("level"),
    dynamic.from(level),
  )
}

/// Sets log level for given handler
pub fn set_handler_log_level(handler: String, level: ConfigLevel) {
  set_handler_config_value(
    atom.create_from_string(handler),
    atom.create_from_string("level"),
    dynamic.from(level),
  )
}

/// Sets a default formatter for default handler
///
/// This function is what we want to recommend as default format or the lib
pub fn set_default_config() {
  set_handler_config_value(
    atom.create_from_string("default"),
    atom.create_from_string("formatter"),
    dynamic.from(#(
      dynamic.from(atom.create_from_string("logger_formatter")),
      dynamic.from(map.from_list([
        #(
          atom.create_from_string("single_line"),
          atom.create_from_string("true"),
        ),
        #(
          atom.create_from_string("legacy_header"),
          atom.create_from_string("false"),
        ),
      ])),
    )),
  )
}

external fn log_string_with_fields(Level, Map(Atom, Dynamic)) -> Nil =
  "logger" "log"

external fn log_string_with_list_map(
  Level,
  String,
  List(Dynamic),
  Map(Atom, Dynamic),
) -> Nil =
  "logger" "log"

pub external fn set_primary_config(Config) -> Nil =
  "logger" "set_primary_config"

external fn set_primary_config_value(Atom, Dynamic) -> Nil =
  "logger" "set_primary_config"

pub external fn set_handler_config(Atom, Config) -> Nil =
  "logger" "set_handler_config"

external fn set_handler_config_value(Atom, Atom, Dynamic) -> Nil =
  "logger" "set_handler_config"

external fn add_handler(Atom, Atom, Dynamic) -> Nil =
  "logger" "add_handler"

external fn get_handler_ids() -> List(Atom) =
  "logger" "get_handler_ids"

external fn get_handler_config(Atom) -> Dynamic =
  "logger" "get_handler_config"

external fn remove_handler(Atom) -> Nil =
  "logger" "remove_handler"

external fn sprintf(String, List(Dynamic)) -> String =
  "io_lib" "format"
