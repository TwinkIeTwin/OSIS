#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QtDebug>
#include <QListWidget>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::on_pushButton_2_clicked()
{
    QListWidget *lw1 = ui->listWidget;
    QString et = ui->lineEdit->text();
    bool ok = true;
    for(int i = 0; i < lw1->count(); ++i)
    {
        QListWidgetItem* item = lw1->item(i);
        if (item->text() == et) {
            ok = false;
            break;
        }
    }
    if(ok)
        lw1->addItem(et);
}

void MainWindow::on_pushButton_3_clicked()
{
    ui->listWidget->clear();
    ui->listWidget_2->clear();
}

void MainWindow::on_pushButton_4_clicked()
{
    if(ui->listWidget->currentItem() != nullptr) {
        ui->listWidget_2->addItem( ui->listWidget->currentItem()->text() );
        ui->listWidget->removeItemWidget(ui->listWidget->currentItem());
        delete ui->listWidget->currentItem();
    }
}

void MainWindow::on_pushButton_5_clicked()
{
    if(ui->listWidget->currentItem() != nullptr) {
        ui->listWidget->removeItemWidget(ui->listWidget->currentItem());
        delete ui->listWidget->currentItem();
    }
    if(ui->listWidget_2->currentItem() != nullptr) {
        ui->listWidget_2->removeItemWidget(ui->listWidget_2->currentItem());
        delete ui->listWidget_2->currentItem();
    }
}
