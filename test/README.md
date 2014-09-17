Testing Mosai Workshop
----------------------

Workshop is tested by its own testing tool `posit`. Although
the tool itself doesn't force any particular directory structure,
we keep an in-house one:

```sh
test/                     # Main test directory
└── matrix.sh             # Test matrix used by `trix`
└── [tool folder]/        # Each tool has its own subdir
    └── resources/        # Resources needed for the tests
    └── unit.test.sh      # The main library unit tests
    └── [...].test.sh     # Other tests

└── [tool folder...]/     # Same for each tool
    └── ...
```
