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

struct RingBuffer<T, const CAPACITY: usize> {
    buffer: [Option<T>; CAPACITY],
    head: usize,
    tail: usize,
    size: usize,
}

// impl<T, const CAPACITY: usize> RingBuffer<T, CAPACITY> {
//     fn new() -> Self {
//         Self {
//             buffer: [(); CAPACITY].map(|_| None),
//             head: 0,
//             tail: 0,
//             size: 0,
//         }
//     }
// }

struct Block {
    num_points: u64,
    start_time: u64,          // epoch
    offsets: Vec<u8>,         // ie [4, 6, 9] = [t + 4, t + 6, t + 9]
    compressed_data: Vec<u8>, // xor encoding (gorilla paper)
}

struct Series {
    head: Box<Block>, // ll of blocks of data
    num_blocks: u64,
}

struct TimeShard {
    map: HashMap<u64, Series>, // ids of a series -> series
}

struct Timeseries<DataPoint> {
    map: HashMap<u64, TimeShard>,
    duration: u64,
    hot_buffer: RingBuffer<DataPoint, 500>,
}
