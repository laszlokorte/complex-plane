wasm-pack build --release
yarn --cwd www run build
scp -r ./public/. laszlo7@laszlo7.uber.space:/var/www/virtual/laszlo7/static.laszlokorte.de/complex-plane
start "https://static.laszlokorte.de/complex-plane/"