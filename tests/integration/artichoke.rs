use crate::run;

const BINARY: &str = "artichoke";
const FIXTURES_ROOT: &str = "./tests/integration/apps/";

#[test]
fn test_hello_world() {
    let app_name = "hello_world.rb";
    let path = format!("{}{}", FIXTURES_ROOT, app_name);
    insta::assert_debug_snapshot!(run(BINARY, vec![&path]));
}

#[test]
fn test_fizz_buzz() {
    let app_name = "fizz_buzz.rb";
    let path = format!("{}{}", FIXTURES_ROOT, app_name);
    insta::assert_debug_snapshot!(run(BINARY, vec![&path]));
}
