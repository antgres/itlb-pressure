\NeedsTeXFormat{LaTeX2e}[2017/01/01]
\ProvidesClass{rwuthesis}[2019/09/02 RWU thesis class]

\RequirePackage{kvoptions}
\RequirePackage{ifthen}
\RequirePackage{translations}

\SetupKeyvalOptions{
	family=rwuthesis,
	prefix=rwuthesis@
}

\newcommand{\rwuthesis@baseclass}{scrreprt}

\DeclareVoidOption{twoside}{%
	\PassOptionsToClass{\CurrentOption}{\rwuthesis@baseclass}
}
\DeclareVoidOption{twocolumn}{%
	\PassOptionsToClass{\CurrentOption}{\rwuthesis@baseclass}
}

\DeclareStringOption{type}
\DeclareStringOption{DIV}
\DeclareStringOption{BCOR}

\ProcessKeyvalOptions*

\PassOptionsToClass{12pt}{\rwuthesis@baseclass}

\LoadClass[listof=nochaptergap]{scrreprt}
\RequirePackage{rwukoma}

\ifthenelse{\equal{\rwuthesis@DIV}{}}{}{%
	\KOMAoption{DIV}{\rwuthesis@DIV}%
}

\ifthenelse{\equal{\rwuthesis@BCOR}{}}{}{%
	\KOMAoption{BCOR}{\rwuthesis@BCOR}%
}

\ifthenelse{\equal{\rwuthesis@type}{bachelor} \OR \equal{\rwuthesis@type}{master}}{%
	\ClassInfo{rwuthesis}{Thesis type is \rwuthesis@type}%
}{%
	\ClassError{rwuthesis}{Thesis type has to be bachelor or master}{%
		Please specify the type option as type=bachelor or type=master\MessageBreak
		when defining the document class, e.g.:\MessageBreak
		\space\space \protect\documentclass[type=bachelor]{rwuthesis}
	}%
}

\DeclareTranslationFallback{rwuthesis-bachelor-thesis}{Bachlor Thesis}
\DeclareTranslation{English}{rwuthesis-bachelor-thesis}{Bachelor Thesis}
\DeclareTranslation{German}{rwuthesis-bachelor-thesis}{Bachelor-Thesis}

\DeclareTranslationFallback{rwuthesis-master-thesis}{Master Thesis}
\DeclareTranslation{English}{rwuthesis-master-thesis}{Master Thesis}
\DeclareTranslation{German}{rwuthesis-master-thesis}{Master-Thesis}

\DeclareTranslationFallback{rwuthesis-degree-course}{Degree Course}
\DeclareTranslation{English}{rwuthesis-degree-course}{Degree Course}
\DeclareTranslation{German}{rwuthesis-degree-course}{Studiengang}

\DeclareTranslationFallback{rwuthesis-faculty}{Faculty of}
\DeclareTranslation{English}{rwuthesis-faculty}{Faculty of}
\DeclareTranslation{German}{rwuthesis-faculty}{Fakultät}

\DeclareTranslationFallback{rwuthesis-first-reviewer}{First Reviewer}
\DeclareTranslation{English}{rwuthesis-first-reviewer}{First Reviewer}
\DeclareTranslation{German}{rwuthesis-first-reviewer}{Erster Gutachter}
\DeclareTranslationFallback{rwuthesis-second-reviewer}{Second Reviewer}
\DeclareTranslation{English}{rwuthesis-second-reviewer}{Second Reviewer}
\DeclareTranslation{German}{rwuthesis-second-reviewer}{Zweiter Gutachter}

\DeclareTranslationFallback{rwuthesis-to-attain}{to attain the academic degree}
\DeclareTranslation{English}{rwuthesis-to-attain}{to attain the academic degree}
\DeclareTranslation{German}{rwuthesis-to-attain}{zur Erlangung des akademischen Grades}

\DeclareTranslationFallback{rwuthesis-submitted-by}{submitted by}
\DeclareTranslation{English}{rwuthesis-submitted-by}{submitted by}
\DeclareTranslation{German}{rwuthesis-submitted-by}{vorgelegt von}

\DeclareTranslationFallback{matriculation-number}{Matriculation number}
\DeclareTranslation{English}{matriculation-number}{Matriculation number}
\DeclareTranslation{German}{matriculation-number}{Matrikelnummer}

\newcommand{\authormail}[1]{\newcommand{\rwuthesis@authormail}{#1}}
\newcommand{\fordegree}[1]{\newcommand{\rwuthesis@fordegree}{#1}}
\newcommand{\firstreviewer}[1]{\newcommand{\rwuthesis@firstreviewer}{#1}}
\newcommand{\firstreviewermail}[1]{\newcommand{\rwuthesis@firstreviewermail}{#1}}
\newcommand{\secondreviewer}[1]{\newcommand{\rwuthesis@secondreviewer}{#1}}
\newcommand{\secondreviewermail}[1]{\newcommand{\rwuthesis@secondreviewermail}{#1}}
\newcommand{\degreecourse}[1]{\newcommand{\rwuthesis@degreecourse}{#1}}
\newcommand{\faculty}[1]{\newcommand{\rwuthesis@faculty}{#1}}
\newcommand{\matnumber}[1]{\newcommand{\rwuthesis@matnumber}{#1}}

\renewcommand{\maketitle}{%
	\begin{titlepage}
		\sffamily
		\begingroup%
			\setlength{\parfillskip}{0pt}%
			\begin{minipage}{\dimexpr\textwidth-6.12cm\relax}%
				\GetTranslation{rwuthesis-degree-course} \rwuthesis@degreecourse\\
				\GetTranslation{rwuthesis-faculty} \rwuthesis@faculty%
			\end{minipage}\hfill\begin{minipage}{5.12cm}%
				\rwulogo%
			\end{minipage}%
			\par%
		\endgroup

		\vfill

		\ifthenelse{\equal{\rwuthesis@type}{bachelor}}{%
			\textbf{\LARGE\GetTranslation{rwuthesis-bachelor-thesis}}
		}{%
			\textbf{\LARGE\GetTranslation{rwuthesis-master-thesis}}
		}

		\textbf{\Large\@title}

		\vfill

		\GetTranslation{rwuthesis-to-attain}\\
		\rwuthesis@fordegree

		\vfill

		\GetTranslation{rwuthesis-submitted-by}:

		\textbf{\Large\@author}
		\ifthenelse{\isundefined{\rwuthesis@authormail}}{%
			\ClassWarning{rwuthesis}{\protect\authormail\space undefined, no mail address on title page}
		}{%
			\\
          \ifthenelse{\isundefined{\rwuthesis@matnumber}}{%
          }{
          \GetTranslation{matriculation-number}: \rwuthesis@matnumber\\
          }
			<\url{\rwuthesis@authormail}>
		}

		\@date

		\vfill

		\begin{tabular}{@{ }ll}
			\GetTranslation{rwuthesis-first-reviewer}: & \rwuthesis@firstreviewer
			\ifthenelse{\isundefined{\rwuthesis@firstreviewermail}}{}{
				<\url{\rwuthesis@firstreviewermail}>%
			}
			\\
			\GetTranslation{rwuthesis-second-reviewer}: & \rwuthesis@secondreviewer
			\ifthenelse{\isundefined{\rwuthesis@secondreviewermail}}{}{
				<\url{\rwuthesis@secondreviewermail}>%
			}
		\end{tabular}
	\end{titlepage}
	\cleardoublepage
}

\endinput
