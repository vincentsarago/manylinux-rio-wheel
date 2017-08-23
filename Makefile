
SHELL = /bin/bash

all: build copy


build:
	docker build --build-arg GithubAccessToken=${GithubAccessToken} --tag wheel:latest .

copy:
	docker run --name wheel -itd wheel:latest /bin/bash
	docker cp wheel:/tmp/wheelhouse/rasterio-1.0a10-cp36-cp36m-manylinux1_x86_64.whl rasterio-1.0a10-cp36-cp36m-manylinux1_x86_64.whl
	docker stop wheel
	docker rm wheel

shell:
	docker run \
		--name wheel  \
		--volume $(shell pwd)/:/data \
		--rm \
		-it \
		wheel:latest /bin/bash

clean:
	docker stop wheel
	docker rm wheel
