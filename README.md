# autoPyenv-zh_TW 自動Pyenv建立/管理腳本

## 給予腳本執行權限
```bash
chmod +x setup_pyenv.sh
```

## 執行
```bash
source ./setup_pyenv.sh
```

## 相依套件自動安裝
建立或啟動專案環境後，腳本會偵測專案內的 `*.toml` 設定檔，並優先支援 `pyproject.toml` 宣告的 Python 相依套件：

- PEP 621 `[project]` / `dependencies`：使用 `pip install -e .`
- Poetry `[tool.poetry]`：已安裝 `poetry` 時使用 `poetry install`，否則回退 `pip install -e .`
- PDM `[tool.pdm]`：已安裝 `pdm` 時使用 `pdm install`，否則回退 `pip install -e .`
- `uv.lock` 且已安裝 `uv`：使用 `uv pip install -e .`

若同時存在 `requirements.txt`，腳本仍會在 TOML 偵測後詢問是否安裝。
