BUILD_NAME=karma-crosscompiler-nogtk

build:
	docker build -f Dockerfile --network=host -t ${BUILD_NAME} .

create:
	docker create ${BUILD_NAME}
