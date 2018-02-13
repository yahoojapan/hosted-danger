setenv:
	./tools/setenv

build: setenv
	docker build . -t hd-image

run:
	docker run -d -it --name hd-container -p 80:80 hd-image

run-i:
	docker run -it --name hd-container -p 80:80 hd-image

stop:
	docker stop hd-container || true
	/usr/local/bin/docker-clean run

rerun: build stop run

rerun-i: build stop run-i
