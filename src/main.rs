fn test(x: &mut u32) {
    *x += 1;
    println!("{}", x);
}

fn main() {
    println!("Hello, world!");
    let mut x: u32 = 5;

    test(&mut x);
}
