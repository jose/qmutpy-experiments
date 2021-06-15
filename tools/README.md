# Tools required to run the experiments and the data analysis

- [Simple Python Version Management: pyenv](https://github.com/pyenv/pyenv)
  and [Virtualenv](https://virtualenv.pypa.io)
- [QMutPy](https://github.com/danielfobooss/mutpy/tree/all_gates)
- [Qiskit Aqua](https://github.com/Qiskit/qiskit-aqua/tree/stable/0.9)
- [R](https://www.r-project.org)

At the moment, [Qiskit Aqua](https://github.com/Qiskit/qiskit-aqua/tree/stable/0.9)
is build with [pyenv](https://github.com/pyenv/pyenv) and [Virtualenv](https://virtualenv.pypa.io),
in the future we might want to investigate other (better?) solutions to create
isolated Python environments.  [This post on stackoverflow](https://stackoverflow.com/a/41573588/998816)
nicely summarize the options available.  Also:
- [pyenv vs pipenv](https://towardsdatascience.com/python-environment-101-1d68bda3094d)
  "If your project depends on Python package versions and its dependencies,
  `pipenv` is for you.
  `pyenv + pyenv-virtualenv` can share packages with different projects.  Whereas
  on `pyenv + pipenv` every project holds own pip/packages without sharing.  If
  you are working in a team, then you should be using `pyenv + pipenv` together.
  If you have a project involving multiple systems such as a local and a remote
  server, then you should be using them as well.  So in a short, if your project
  involves more than one system you should be using `pyenv + pipenv`."
