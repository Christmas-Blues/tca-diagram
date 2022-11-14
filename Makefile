all: clean build

build:
	swift build -c release --arch arm64 --arch x86_64

test:
	swift test

clean:
	rm -rf .build
