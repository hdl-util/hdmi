files = [
    "top.sv",
]

modules = {
    "local": [
        "../src"
    ],
    "git": [
        "git@github.com:hdl-util/pll.git::master"
    ]
}

fetchto = "../ip_cores"
