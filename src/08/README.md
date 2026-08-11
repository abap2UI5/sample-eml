# 08 — MIME Play Audio

*[← all packages](../../README.md)*

[`487`](z2ui5_cl_smpe_app_487.clas.abap) plays a sound stored in the **MIME
repository**, addressed by its ICF path — a success and an error tone, both shipped
with this package ([`src/08/01`](01)).

A small sample with a general point: anything the system already serves over an ICF
path — a sound, an image, a document — is one URL away from an abap2UI5 view. The
repository stays where it is; the app only points at it.

## What you need

**Setup:** activate the ICF service `/SAP/PUBLIC/BC/ABAP/mime_demo` in `SICF`. The
app checks the node and warns if it is inactive.

## The sample

Start it with `?app_start=z2ui5_cl_smpe_app_487`. Type the magic key the app tells
you and you get the success sound; type anything else and you get the error one.

## Where to go next

- [`01` OData](../01/README.md) — back to the beginning: data from a service instead
  of bytes from the repository.
