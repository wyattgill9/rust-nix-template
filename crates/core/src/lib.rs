use std::collections::HashMap;

capnp::generated_code!(mod point_capnp);

pub fn test() {
    let mut builder = capnp::message::Builder::new_default();

    let mut point_msg = builder.init_root::<point_capnp::point::Builder>();
    point_msg.set_x(100);
    point_msg.set_y(50);

    let mut buffer = Vec::new();
    capnp::serialize::write_message(&mut buffer, &builder).unwrap();

    let deserialized = capnp::serialize::read_message(
        &mut buffer.as_slice(),
        capnp::message::ReaderOptions::new(),
    )
    .unwrap();

    let point_reader = deserialized
        .get_root::<point_capnp::point::Reader>()
        .unwrap();

    println!("{}", point_reader.get_x());
}
