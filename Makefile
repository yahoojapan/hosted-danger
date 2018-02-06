setenv:
	./tools/setenv

build: setenv
	sudo docker build . -t hd-image

run: build
	sudo docker run -d -it --name hd-container -p 80:80 hd-image

run-i: build
	sudo docker run -it --name hd-container -p 80:80 hd-image

stop:
	sudo docker stop hd-container || true
	sudo /usr/local/bin/docker-clean run

rerun: stop run

rerun-i: stop run-i
