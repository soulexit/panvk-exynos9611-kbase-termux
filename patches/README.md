# Local patch series

`scripts/fetch-source.sh` checks out the pinned base commit and applies every `*.patch` in this
directory in filename order with `git apply`. Keep the numeration (`0001-…`) and one logical change
per patch.

The base tree already contains the Bifrost v6 kbase path. This directory starts empty on purpose:
add a patch only after a device test shows it is needed, and document:

```text
Purpose:
Symptom before the patch:
Tested GPU + kbase:
Tested kernel / Android:
Base commit:
Validation:
```

Patch format is `git format-patch`-compatible. Do not reorder or rewrite a patch that has shipped in
a release; add the next number instead.
