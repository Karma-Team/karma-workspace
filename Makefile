BUILD_NAME=karma-crosscompiler-nogtk

build:
	docker build -f Dockerfile --network=host -t ${BUILD_NAME} .

create: .container

.container:
	docker create ${BUILD_NAME} > .container

save-image:
	docker image save -o ${BUILD_NAME}.tar.gz ${BUILD_NAME}:latest

load-image:
	docker image import ${BUILD_NAME}.tar.gz

copy-include: .container
	docker cp $(cat .container):/opt/opencv-4.2.0/include/opencv4/opencv2 toolsChain/include/


clean:
	rm -r toolsChain/opencv2
	rm .container

