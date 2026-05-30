.PHONY: test test-unit test-integration test-e2e docker-e2e clean lint

EMACS ?= emacs
BATCH_FLAGS = --batch -Q

# 단위 테스트 (빠른 피드백)
test-unit:
	$(EMACS) $(BATCH_FLAGS) \
		-l tests/test-org-render-core.el \
		-f ert-run-tests-batch-and-exit

# 통합 테스트
test-integration:
	$(EMACS) $(BATCH_FLAGS) \
		-l tests/test-org-render-integration.el \
		-f ert-run-tests-batch-and-exit

# Docker E2E 테스트
test-e2e:
	$(EMACS) $(BATCH_FLAGS) \
		-l tests/test-e2e-docker.el \
		-f ert-run-tests-batch-and-exit

# Docker 컨테이너에서 E2E
docker-e2e:
	docker compose up --build --abort-on-container-exit

# 전체 테스트
test: test-unit test-integration test-e2e

# 린트
lint:
	$(EMACS) $(BATCH_FLAGS) \
		-l agent-shell-org-render.el \
		--eval "(byte-compile-file \"agent-shell-org-render.el\" t)"

# 정리
clean:
	rm -f *.png *.svg *.pdf *.elc
	rm -rf tests/*.png tests/*.svg tests/*.pdf
