FROM python:3.13-slim

RUN python -m pip install --upgrade --no-cache-dir pip \
    && pip install --no-cache-dir elasticsearch requests

COPY tester.py /tester.py

CMD ["python","/tester.py"]
