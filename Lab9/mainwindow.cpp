#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <thread>

#include <QtDebug>

static int j=0;
static QPoint python[20];

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    timer = new QTimer(this);
    connect(timer, SIGNAL(timeout()), this, SLOT(onTimeout()));
    timer->setInterval(20);
    timer->start();

}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::onTimeout(){
    j = (j + 3) % 359;

    QPoint pos = QWidget::mapFromGlobal(QCursor::pos()) - QPoint(16,16);
    if (pos != python[0]){
        for (int i = 19; i >= 1; i--){
            python[i] = python[i-1];
        }
        python[0] = pos;

    }
    repaint();
}

void MainWindow::paintEvent(QPaintEvent *event) {

        QPainter *paint = new QPainter(this);

        paint->setPen(QPen(Qt::black, 0));
        paint->setRenderHint(QPainter::Antialiasing, true);

        paint->fillRect(0, 0, width(), height(), Qt::SolidPattern);

        paint->setBrush(QBrush(QColor::fromHsv(j,255, 255), Qt::Dense6Pattern));

        for ( int i =0; i < 20; i++){
            paint->drawEllipse(python[i].x(), python[i].y(), 32, 32);
        }

        paint->end();

}
