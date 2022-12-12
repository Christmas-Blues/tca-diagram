all: clean build

build:
	swift build -c release --arch arm64 --arch x86_64

test:
	swift test

release: clean test build
	gh release create $(VERSION) \
		--title $(VERSION) \
		--generate-notes \
		.build/apple/Products/Release/tca-diagram

clean:
	rm -rf .build
