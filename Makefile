BUILD_NAME=karma-crosscompiler

build:
	docker build -f Dockerfile --network=host -t ${BUILD_NAME} .

create:
	docker create ${BUILD_NAME}
