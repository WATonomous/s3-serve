# s3-serve

Runs [serve][serve] with an [S3-compatible backend][mountpoint-s3]. Useful for serving websites from S3[^rewrite].

[serve]: https://github.com/vercel/serve
[mountpoint-s3]: https://github.com/awslabs/mountpoint-s3
[^rewrite]: S3 does not support [clean URLs](https://github.com/vercel/serve-handler/blob/da507891/README.md#cleanurls-booleanarray). The closest you can get is to use [index documents](https://docs.aws.amazon.com/AmazonS3/latest/userguide/IndexDocumentSupport.html), but this only supports `index.html` and not other files (e.g. `about.html`. A workaround is to convert all `<name>.html` files to `<name>/index.html` files, but that is error-prone because it's not the default behaviour of frameworks like [Next.js](https://nextjs.org/)). Moreover, in some S3-compatible storage backends like [Ceph Object Gateway](https://docs.ceph.com/en/latest/radosgw/s3/), the support for index documents requires setting `rgw_dns_name` and `rgw_dns_s3website_name`, which restricts the RGW instance to only serve from two domains. On the other hand, [serve][serve] supports clean URLs the box. This project combines the two to provide clean URLs on S3.

## Getting started

```bash
export AWS_ACCESS_KEY_ID=<access_key_id>
export AWS_SECRET_ACCESS_KEY=<secret_key>
export S3_ENDPOINT_URL=<endpoint_url>
export S3_BUCKET=<bucket_name>

docker run --rm --cap-add SYS_ADMIN --device /dev/fuse --name s3-serve \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e S3_ENDPOINT_URL \
    -e S3_BUCKET \
    -p 3000:3000 \
    ghcr.io/watonomous/s3-serve
```

### Use path-style addressing

If your S3 endpoint does not support virtual-hosted-style addressing, you can use path-style addressing by including `--force-path-style` in the `MOUNTPOINT_S3_ADDITIONAL_ARGS` environment variable:

```bash
# In addition to the above environment variables
export MOUNTPOINT_S3_ADDITIONAL_ARGS="--force-path-style"

docker run --rm --cap-add SYS_ADMIN --device /dev/fuse --name s3-serve \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e S3_ENDPOINT_URL \
    -e S3_BUCKET \
    -e MOUNTPOINT_S3_ADDITIONAL_ARGS \
    -p 3000:3000 \
    ghcr.io/watonomous/s3-serve
```

### Reduce logging

By default, [serve][serve] and [mountpoint-s3][mountpoint-s3] log all requests[^logging]. You can reduce the amount of logging by including the following environment variables:

```bash
# In addition to the above environment variables
export SERVE_ADDITIONAL_ARGS="--no-request-logging"
export MOUNTPOINT_LOG="error,awscrt=off"

docker run --rm --cap-add SYS_ADMIN --device /dev/fuse --name s3-serve \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e S3_ENDPOINT_URL \
    -e S3_BUCKET \
    -e SERVE_ADDITIONAL_ARGS \
    -e MOUNTPOINT_LOG \
    -p 3000:3000 \
    ghcr.io/watonomous/s3-serve
```

[^logging]: [`serve` logging documentation](https://github.com/vercel/serve/blob/1ea55b/source/utilities/cli.ts#L47), `mountpoint-s3` logging documentation [1](https://github.com/awslabs/mountpoint-s3/blob/27bac02/doc/LOGGING.md) [2](https://github.com/awslabs/mountpoint-s3/blob/27bac02/mountpoint-s3/src/main.rs#L289-L304)

### Use a custom `serve` configuration

You can use a custom `serve` configuration by mounting a [`serve.json`](https://github.com/vercel/serve/blob/1ea55b/readme.md#configuration) file to `/etc/serve.json`:

```bash
docker run --rm --cap-add SYS_ADMIN --device /dev/fuse --name s3-serve \
    -e AWS_ACCESS_KEY_ID \
    -e AWS_SECRET_ACCESS_KEY \
    -e S3_ENDPOINT_URL \
    -e S3_BUCKET \
    -v /path/to/serve.json:/etc/serve.json:ro \
    -p 3000:3000 \
    ghcr.io/watonomous/s3-serve
```

