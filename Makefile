BUILD_NAME=karmateam/karma-crosscompiler-nogtk

build:
	docker build --no-cache -f Dockerfile --network=host -t ${BUILD_NAME} .

pull:
	docker pull ${BUILD_NAME}

push:
	docker push ${BUILD_NAME}

.container:
	docker create ${BUILD_NAME} > .container

toolsChain:
	wget https://drive.google.com/open?id=1xslCVDkM9jt5LxSARN-TDuqKrP2hwnmI
	tar xf toolsChain
	rm toolsChain.tar.gz

docker:
	docker pull karmateam/karma-crosscompiler-nogtk:latest

opencv: .container toolsChain
	docker cp `cat .container`:/opt/opencv-4.2.0/include/opencv4/opencv2 toolsChain/include/

setup-env: opencv

clean:
	rm -rf toolsChain
	rm -f .container
	#rm -f ${BUILD_NAME}.tar.gz

