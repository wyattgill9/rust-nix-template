extern crate capnpc;

fn main() {
    ::capnpc::CompilerCommand::new()
        .src_prefix("schema")
        .file("schema/point.capnp")
        .run()
        .expect("compiling schema");
}
