Testing Mosai Workshop
----------------------

Workshop is tested by its own testing tool `testsuite`. Although 
the tool itself doesn't force any particular directory structure, 
we keep an in-house one:

```sh
test/                     # Main test directory
└── [tool folder]/        # Each tool has its own subdir
    └── resources/        # Resources needed for the tests
    └── library.test.sh   # The main library test
    └── [...].test.sh     # Other tests

└── [tool folder...]/     # Same for each tool
    └── ...
```

Each test